import numpy as np
import pandas as pd
import torch
from torch_geometric.data import Data
import networkx as nx
from sklearn.preprocessing import StandardScaler

class TrafficDataLoader:
    def __init__(self):
        self.scaler = StandardScaler()
        
    def load_traffic_data(self, traffic_data_path, road_network_path):
        """
        Load traffic data and road network data.
        
        Args:
            traffic_data_path (str): Path to traffic data CSV file
            road_network_path (str): Path to road network data CSV file
        
        Returns:
            tuple: (node_features, edge_index, edge_weights, labels)
        """
        # Load traffic data
        traffic_df = pd.read_csv(traffic_data_path)
        
        # Load road network data
        road_network_df = pd.read_csv(road_network_path)
        
        # Create graph from road network
        G = nx.Graph()
        
        # Add nodes (intersections)
        for _, row in road_network_df.iterrows():
            G.add_node(row['intersection_id'], 
                      pos=(row['longitude'], row['latitude']))
        
        # Add edges (road segments)
        for _, row in road_network_df.iterrows():
            G.add_edge(row['from_intersection'], 
                      row['to_intersection'],
                      weight=row['distance'])
        
        # Extract node features
        node_features = []
        for node in G.nodes():
            # Get traffic metrics for this intersection
            node_data = traffic_df[traffic_df['intersection_id'] == node]
            features = [
                node_data['traffic_volume'].mean(),
                node_data['average_speed'].mean(),
                node_data['congestion_level'].mean(),
                G.degree(node),
                G.nodes[node]['pos'][0],  # longitude
                G.nodes[node]['pos'][1]   # latitude
            ]
            node_features.append(features)
        
        # Convert to numpy array and normalize
        node_features = np.array(node_features)
        node_features = self.scaler.fit_transform(node_features)
        
        # Create edge index and weights
        edge_index = []
        edge_weights = []
        for u, v, data in G.edges(data=True):
            edge_index.append([u, v])
            edge_weights.append(data['weight'])
        
        edge_index = np.array(edge_index).T
        edge_weights = np.array(edge_weights)
        
        # Create labels (traffic congestion levels)
        labels = traffic_df.groupby('intersection_id')['congestion_level'].mean().values
        
        return node_features, edge_index, edge_weights, labels
    
    def create_graph_data(self, node_features, edge_index, edge_weights, labels):
        """
        Create PyTorch Geometric Data object.
        
        Args:
            node_features (np.ndarray): Node feature matrix
            edge_index (np.ndarray): Edge connectivity matrix
            edge_weights (np.ndarray): Edge weights
            labels (np.ndarray): Node labels
        
        Returns:
            torch_geometric.data.Data: PyTorch Geometric Data object
        """
        x = torch.tensor(node_features, dtype=torch.float)
        edge_index = torch.tensor(edge_index, dtype=torch.long)
        edge_weights = torch.tensor(edge_weights, dtype=torch.float)
        y = torch.tensor(labels, dtype=torch.long)
        
        return Data(x=x, edge_index=edge_index, edge_weight=edge_weights, y=y)
    
    def create_train_test_split(self, data, train_ratio=0.8):
        """
        Create train/test split for the data.
        
        Args:
            data (torch_geometric.data.Data): Input data
            train_ratio (float): Ratio of training data
        
        Returns:
            torch_geometric.data.Data: Data with train/test masks
        """
        num_nodes = data.x.size(0)
        num_train = int(train_ratio * num_nodes)
        
        # Create random permutation
        indices = torch.randperm(num_nodes)
        
        # Create masks
        train_mask = torch.zeros(num_nodes, dtype=torch.bool)
        test_mask = torch.zeros(num_nodes, dtype=torch.bool)
        
        train_mask[indices[:num_train]] = True
        test_mask[indices[num_train:]] = True
        
        data.train_mask = train_mask
        data.test_mask = test_mask
        
        return data 
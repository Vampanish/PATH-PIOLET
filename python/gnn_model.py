import torch
import torch.nn.functional as F
from torch_geometric.nn import GCNConv, GATConv
from torch_geometric.data import Data
import numpy as np

class TrafficGNN(torch.nn.Module):
    def __init__(self, num_features, hidden_channels, num_classes):
        super(TrafficGNN, self).__init__()
        # Graph Convolutional Layers
        self.conv1 = GCNConv(num_features, hidden_channels)
        self.conv2 = GCNConv(hidden_channels, hidden_channels)
        
        # Graph Attention Layer
        self.attention = GATConv(hidden_channels, hidden_channels)
        
        # Output layer
        self.classifier = torch.nn.Linear(hidden_channels, num_classes)
        
    def forward(self, x, edge_index, edge_weight=None):
        # First GCN layer with ReLU activation
        x = self.conv1(x, edge_index, edge_weight)
        x = F.relu(x)
        x = F.dropout(x, p=0.2, training=self.training)
        
        # Second GCN layer
        x = self.conv2(x, edge_index, edge_weight)
        x = F.relu(x)
        
        # Graph Attention layer
        x = self.attention(x, edge_index)
        x = F.relu(x)
        
        # Classification layer
        x = self.classifier(x)
        
        return x

def create_graph_data(node_features, edge_index, edge_weights=None):
    """
    Create a PyTorch Geometric Data object from node features and edge information.
    
    Args:
        node_features (np.ndarray): Node feature matrix of shape (num_nodes, num_features)
        edge_index (np.ndarray): Edge connectivity matrix of shape (2, num_edges)
        edge_weights (np.ndarray, optional): Edge weights of shape (num_edges,)
    
    Returns:
        torch_geometric.data.Data: PyTorch Geometric Data object
    """
    # Convert numpy arrays to torch tensors
    x = torch.tensor(node_features, dtype=torch.float)
    edge_index = torch.tensor(edge_index, dtype=torch.long)
    
    if edge_weights is not None:
        edge_weights = torch.tensor(edge_weights, dtype=torch.float)
    
    return Data(x=x, edge_index=edge_index, edge_weight=edge_weights)

def train_model(model, data, optimizer, epochs=200):
    """
    Train the GNN model.
    
    Args:
        model (TrafficGNN): The GNN model
        data (torch_geometric.data.Data): Training data
        optimizer (torch.optim.Optimizer): Optimizer
        epochs (int): Number of training epochs
    """
    model.train()
    
    for epoch in range(epochs):
        optimizer.zero_grad()
        out = model(data.x, data.edge_index, data.edge_weight)
        loss = F.cross_entropy(out[data.train_mask], data.y[data.train_mask])
        loss.backward()
        optimizer.step()
        
        if (epoch + 1) % 10 == 0:
            print(f'Epoch: {epoch+1:03d}, Loss: {loss.item():.4f}')

def evaluate_model(model, data):
    """
    Evaluate the trained model.
    
    Args:
        model (TrafficGNN): The trained GNN model
        data (torch_geometric.data.Data): Test data
    
    Returns:
        float: Accuracy on the test set
    """
    model.eval()
    with torch.no_grad():
        out = model(data.x, data.edge_index, data.edge_weight)
        pred = out.argmax(dim=1)
        correct = int((pred[data.test_mask] == data.y[data.test_mask]).sum())
        acc = correct / int(data.test_mask.sum())
    return acc 
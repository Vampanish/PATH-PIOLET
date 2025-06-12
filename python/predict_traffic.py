import torch
import numpy as np
from gnn_model import TrafficGNN
from traffic_data_loader import TrafficDataLoader
import matplotlib.pyplot as plt
import seaborn as sns

def visualize_predictions(data, predictions, true_labels=None):
    """
    Visualize the predictions on a map.
    
    Args:
        data (torch_geometric.data.Data): Graph data
        predictions (np.ndarray): Model predictions
        true_labels (np.ndarray, optional): True labels for comparison
    """
    # Get node positions
    positions = data.x[:, -2:].numpy()  # Last two features are lat/long
    
    plt.figure(figsize=(12, 8))
    
    # Create scatter plot
    scatter = plt.scatter(
        positions[:, 0],  # longitude
        positions[:, 1],  # latitude
        c=predictions,
        cmap='RdYlGn_r',
        s=100,
        alpha=0.6
    )
    
    # Add colorbar
    plt.colorbar(scatter, label='Predicted Congestion Level')
    
    # Add title and labels
    plt.title('Traffic Congestion Predictions')
    plt.xlabel('Longitude')
    plt.ylabel('Latitude')
    
    # Save plot
    plt.savefig('traffic_predictions.png')
    plt.close()

def main():
    # Initialize data loader
    data_loader = TrafficDataLoader()
    
    # Load data
    print("Loading traffic data...")
    node_features, edge_index, edge_weights, labels = data_loader.load_traffic_data(
        traffic_data_path='data/traffic_data.csv',
        road_network_path='data/road_network.csv'
    )
    
    # Create graph data
    data = data_loader.create_graph_data(
        node_features, edge_index, edge_weights, labels
    )
    
    # Initialize model
    num_features = node_features.shape[1]
    hidden_channels = 64
    num_classes = len(np.unique(labels))
    
    model = TrafficGNN(
        num_features=num_features,
        hidden_channels=hidden_channels,
        num_classes=num_classes
    )
    
    # Load trained model
    model.load_state_dict(torch.load('traffic_gnn_model.pth'))
    model.eval()
    
    # Make predictions
    print("Making predictions...")
    with torch.no_grad():
        out = model(data.x, data.edge_index, data.edge_weight)
        predictions = out.argmax(dim=1).numpy()
    
    # Visualize predictions
    print("Visualizing predictions...")
    visualize_predictions(data, predictions, labels)
    
    # Print prediction statistics
    print("\nPrediction Statistics:")
    print(f"Number of nodes: {len(predictions)}")
    print("\nCongestion Level Distribution:")
    unique, counts = np.unique(predictions, return_counts=True)
    for level, count in zip(unique, counts):
        print(f"Level {level}: {count} nodes ({count/len(predictions)*100:.1f}%)")
    
    # Calculate accuracy if true labels are available
    if labels is not None:
        accuracy = np.mean(predictions == labels)
        print(f"\nPrediction Accuracy: {accuracy:.4f}")

if __name__ == "__main__":
    main() 
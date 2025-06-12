import numpy as np
import torch
from gnn_model import TrafficGNN, create_graph_data, train_model, evaluate_model

def generate_sample_data(num_nodes=100, num_features=10, num_classes=3):
    """
    Generate sample data for demonstration purposes.
    
    Args:
        num_nodes (int): Number of nodes in the graph
        num_features (int): Number of features per node
        num_classes (int): Number of classes for classification
    
    Returns:
        tuple: (node_features, edge_index, edge_weights, labels)
    """
    # Generate random node features
    node_features = np.random.randn(num_nodes, num_features)
    
    # Generate random edges (sparse connectivity)
    num_edges = num_nodes * 3  # Average 3 edges per node
    edge_index = np.random.randint(0, num_nodes, size=(2, num_edges))
    
    # Generate random edge weights
    edge_weights = np.random.rand(num_edges)
    
    # Generate random labels
    labels = np.random.randint(0, num_classes, size=num_nodes)
    
    return node_features, edge_index, edge_weights, labels

def main():
    # Set random seed for reproducibility
    torch.manual_seed(42)
    np.random.seed(42)
    
    # Generate sample data
    num_nodes = 100
    num_features = 10
    num_classes = 3
    hidden_channels = 64
    
    node_features, edge_index, edge_weights, labels = generate_sample_data(
        num_nodes=num_nodes,
        num_features=num_features,
        num_classes=num_classes
    )
    
    # Create graph data
    data = create_graph_data(node_features, edge_index, edge_weights)
    data.y = torch.tensor(labels, dtype=torch.long)
    
    # Create train/test masks
    num_train = int(0.8 * num_nodes)
    train_mask = torch.zeros(num_nodes, dtype=torch.bool)
    train_mask[:num_train] = True
    test_mask = ~train_mask
    data.train_mask = train_mask
    data.test_mask = test_mask
    
    # Initialize model
    model = TrafficGNN(
        num_features=num_features,
        hidden_channels=hidden_channels,
        num_classes=num_classes
    )
    
    # Initialize optimizer
    optimizer = torch.optim.Adam(model.parameters(), lr=0.01)
    
    # Train model
    print("Training model...")
    train_model(model, data, optimizer, epochs=200)
    
    # Evaluate model
    accuracy = evaluate_model(model, data)
    print(f"\nTest Accuracy: {accuracy:.4f}")

if __name__ == "__main__":
    main() 
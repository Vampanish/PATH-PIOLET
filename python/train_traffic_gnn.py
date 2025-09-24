import torch
import torch.nn.functional as F
from gnn_model import TrafficGNN
from traffic_data_loader import TrafficDataLoader
import matplotlib.pyplot as plt
import numpy as np

def plot_training_progress(train_losses, test_accuracies):
    """
    Plot training progress.
    
    Args:
        train_losses (list): List of training losses
        test_accuracies (list): List of test accuracies
    """
    plt.figure(figsize=(12, 4))
    
    # Plot training loss
    plt.subplot(1, 2, 1)
    plt.plot(train_losses, label='Training Loss')
    plt.xlabel('Epoch')
    plt.ylabel('Loss')
    plt.title('Training Loss over Time')
    plt.legend()
    
    # Plot test accuracy
    plt.subplot(1, 2, 2)
    plt.plot(test_accuracies, label='Test Accuracy')
    plt.xlabel('Epoch')
    plt.ylabel('Accuracy')
    plt.title('Test Accuracy over Time')
    plt.legend()
    
    plt.tight_layout()
    plt.savefig('training_progress.png')
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
    
    # Create train/test split
    data = data_loader.create_train_test_split(data)
    
    # Initialize model
    num_features = node_features.shape[1]
    hidden_channels = 64
    num_classes = len(np.unique(labels))
    
    model = TrafficGNN(
        num_features=num_features,
        hidden_channels=hidden_channels,
        num_classes=num_classes
    )
    
    # Initialize optimizer
    optimizer = torch.optim.Adam(model.parameters(), lr=0.01)
    
    # Training loop
    print("Training model...")
    train_losses = []
    test_accuracies = []
    
    for epoch in range(200):
        model.train()
        optimizer.zero_grad()
        
        # Forward pass
        out = model(data.x, data.edge_index, data.edge_weight)
        loss = F.cross_entropy(out[data.train_mask], data.y[data.train_mask])
        
        # Backward pass
        loss.backward()
        optimizer.step()
        
        # Record training loss
        train_losses.append(loss.item())
        
        # Evaluate on test set
        model.eval()
        with torch.no_grad():
            out = model(data.x, data.edge_index, data.edge_weight)
            pred = out.argmax(dim=1)
            correct = int((pred[data.test_mask] == data.y[data.test_mask]).sum())
            acc = correct / int(data.test_mask.sum())
            test_accuracies.append(acc)
        
        if (epoch + 1) % 10 == 0:
            print(f'Epoch: {epoch+1:03d}, Loss: {loss.item():.4f}, Test Acc: {acc:.4f}')
    
    # Plot training progress
    plot_training_progress(train_losses, test_accuracies)
    
    # Save the trained model
    torch.save(model.state_dict(), 'traffic_gnn_model.pth')
    print("\nModel saved as 'traffic_gnn_model.pth'")

if __name__ == "__main__":
    main() 
#!/bin/bash

echo "================================="
echo "CockroachDB Cluster Shutdown"
echo "================================="

echo ""
echo "⚠️  IMPORTANT: Graceful shutdown order:"
echo "1. Stop worker nodes first (VM2, VM3)"
echo "2. Stop bootstrap node last (VM1)"
echo ""

echo "🛑 Recommended shutdown sequence:"
echo ""

echo "📍 Step 1: Run on VM 2:"
echo "   ./down-vm2.sh"
echo ""

echo "📍 Step 2: Run on VM 3:"
echo "   ./down-vm3.sh"
echo ""

echo "📍 Step 3: Run on VM 1 (last):"
echo "   ./down-vm1.sh"
echo ""

echo "🧹 Optional: Clean up Docker resources on each VM:"
echo "   VM 1: ./prune-vm1.sh"
echo "   VM 2: ./prune-vm2.sh"
echo "   VM 3: ./prune-vm3.sh"
echo ""

read -p "❓ Are you running this on VM 1? (y/N): " choice
case "$choice" in 
  y|Y ) 
    echo ""
    echo "🔻 Shutting down VM 1 (Bootstrap node)..."
    echo "⚠️  Make sure VM 2 and VM 3 are already stopped!"
    echo ""
    read -p "Press Enter to continue or Ctrl+C to cancel..."
    ./down-vm1.sh
    echo ""
    echo "✅ VM 1 shutdown complete!"
    echo ""
    read -p "🧹 Do you want to clean up Docker resources? (y/N): " cleanup
    case "$cleanup" in
      y|Y )
        ./prune-vm1.sh
        ;;
      * )
        echo "Skipped cleanup. Run ./prune-vm1.sh later if needed."
        ;;
    esac
    ;;
  * ) 
    echo ""
    echo "📝 Manual shutdown instructions:"
    echo "1. On VM 2: ./down-vm2.sh"
    echo "2. On VM 3: ./down-vm3.sh"
    echo "3. On VM 1: ./down-vm1.sh"
    echo ""
    echo "Exiting..."
    ;;
esac 
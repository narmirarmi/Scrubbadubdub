#!/bin/bash
#
# setup-demo.sh - Sets up the demo environment for safecmd.sh
# This script creates test users and configures the system for the demo

# Create demo users (will only work if run as root or with sudo)
create_demo_users() {
  echo "Creating demo users..."
  sudo useradd -m demo_admin
  sudo useradd -m demo_operator
  sudo useradd -m demo_dev

  echo "Setting passwords for demo users..."
  echo "demo_admin:password123" | sudo chpasswd
  echo "demo_operator:password123" | sudo chpasswd
  echo "demo_dev:password123" | sudo chpasswd

  echo "Users created successfully!"
}

# Set up test directory structure
setup_test_directories() {
  echo "Setting up test directories..."

  # Create a test directory structure
  mkdir -p ~/demo_tests/important_data
  mkdir -p ~/demo_tests/backups
  mkdir -p ~/demo_tests/temp

  # Create some dummy files
  echo "This is critical company data" > ~/demo_tests/important_data/critical.txt
  echo "These are customer records" > ~/demo_tests/important_data/customers.dat
  echo "Backup from last week" > ~/demo_tests/backups/backup_old.tar
  echo "Temporary file" > ~/demo_tests/temp/temp1.txt

  echo "Test directories created successfully!"
}

# Install the safecmd wrapper
install_safecmd() {
  echo "Installing safecmd wrapper..."

  # Copy the safecmd script
  cp safecmd.sh ~/safecmd.sh
  chmod +x ~/safecmd.sh

  # Create wrapper scripts for dangerous commands
  for cmd in rm chmod chown dd mv rsync; do
    echo "Creating wrapper for $cmd..."
    cat > ~/safe_$cmd <<EOF
#!/bin/bash
# Wrapper for $cmd that uses safecmd.sh for safety checks
~/safecmd.sh $cmd "\$@"
EOF
    chmod +x ~/safe_$cmd
  done

  echo "safecmd wrapper installed successfully!"
}

# Run all setup steps
create_demo_users
setup_test_directories
install_safecmd

echo "Demo environment setup complete!"
echo "You can now demo the safecmd.sh script with different users and commands."
echo ""
echo "Demo commands to try:"
echo "1. Safe command (as any user): ~/safe_rm temp1.txt"
echo "2. Dangerous command (as operator): ~/safe_rm -rf /"
echo "3. Unauthorized command (as developer): ~/safe_chmod 777 file.txt"
echo ""
echo "To switch users for testing: sudo su - demo_admin"
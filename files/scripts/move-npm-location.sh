# Create a directory for global packages
mkdir ~/.npm-global

# Configure npm to use it
npm config set prefix '~/.npm-global'

# Add to your PATH (add this to ~/.bashrc or ~/.zshrc)
export PATH=~/.npm-global/bin:$PATH

#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Remove existing HTML documentation
rm -rf docs/html

# create docs directory if it doesn't exist
if [ ! -d ../../docs ]; then
    mkdir -p ../../docs
fi

# Create Doxyfile
echo "Generating Doxyfile..."
if [ -f ../../docs/Doxyfile ]; then
    echo "Doxyfile already exists. Overwriting..."

    cp ../../docs/Doxyfile Doxyfile
else
    echo "Creating new Doxyfile..."
cat <<EOL > Doxyfile
# Doxyfile Minimal Configuration (with Class Diagrams)
#---------------------------------------------------------------------------
# Project related configuration options
#---------------------------------------------------------------------------
PROJECT_NAME           = "MyProject"     # <--- SET YOUR PROJECT NAME!
OUTPUT_DIRECTORY       = docs            # Directory for all output (relative to Doxyfile)
INPUT                  = ../../          # <--- SET YOUR SOURCE CODE DIRS! (e.g., src include)
RECURSIVE              = YES             # Scan subdirectories
#---------------------------------------------------------------------------
# Configuration options related to documentation extraction
#---------------------------------------------------------------------------
EXTRACT_ALL            = YES             # Document everything, even undocumented members (set to NO for cleaner final docs)
EXTRACT_PRIVATE        = NO              # Do not document private members
EXTRACT_STATIC         = YES             # Document static members
#---------------------------------------------------------------------------
# Configuration options related to HTML output
#---------------------------------------------------------------------------
GENERATE_HTML          = YES             # Generate HTML
HTML_OUTPUT            = html            # Subdirectory for HTML files (inside OUTPUT_DIRECTORY)
GENERATE_TREEVIEW      = YES             # Add a navigation tree panel (recommended)
#---------------------------------------------------------------------------
# Configuration options related to diagrams and graphs (Requires Graphviz/dot)
#---------------------------------------------------------------------------
HAVE_DOT               = YES             # Set to YES if you have Graphviz/dot installed
USE_MATHJAX            = YES
CLASS_DIAGRAMS         = YES             # Generate class diagrams
# HIDE_UNDOC_RELATIONS = NO              # Set to YES to hide relations for undocumented classes/members
UML_LOOK               = YES             # Use UML-style diagrams (recommended)
# DOT_PATH             =                 # Only set if 'dot' is not in your system PATH
#---------------------------------------------------------------------------
# Other useful settings (optional)
#---------------------------------------------------------------------------
# QUIET                = YES             # Less verbose output during generation
# WARN_IF_UNDOCUMENTED = YES             # Warn about undocumented members (useful with EXTRACT_ALL = NO)
# FILE_PATTERNS        = *.c *.cpp *.h *.hpp *.md # Adjust if needed
EOL

    # copy Doxyfile to docs directory
    cp Doxyfile ../../docs/Doxyfile
    echo "Doxyfile created successfully."
fi

# Create README.md if it doesn't exist
if [ ! -f ../../README.md ]; then
    echo "Creating README.md..."
    cat <<EOL > ../../README.md
# MyProject
This is a sample project to demonstrate Doxygen documentation generation.
EOL
else
    echo "README.md already exists. Skipping creation."
fi

# Run Doxygen to generate documentation
echo "Running Doxygen..."
doxygen Doxyfile

# Open the generated documentation in Google Chrome
if command -v google-chrome &> /dev/null; then
    echo "Opening documentation in Google Chrome..."
    google-chrome docs/html/index.html
else
    echo "Google Chrome is not installed or not in PATH. Please open docs/html/index.html manually."
fi

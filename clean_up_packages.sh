#!/bin/bash

# Keep only last version of the package.
sudo paccache -rk 1

# Remove all versions from uninstalled packages.
sudo paccache -ruk0
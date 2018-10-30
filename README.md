# EdgeLB pool size tester
Tool to test maximal EdgeLB pool size. Work in progress, now supports only simple frontend-backend pairs without SSL.

Usage: `./loadtester.sh <desired load> <port range start>`

This will spawn desired number of apps and generate an EdgeLB pool to expose them. 

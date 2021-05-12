## Clean system (Safe)
sudo docker system prune

## Clean all images
sudo docker rmi $(sudo docker images -q)


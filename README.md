# <img src="./icon.svg" width="24px"> PyramidContainer

A container that arranges its child controls in the shape of a pyramid. That is, the <_biggest included power of two_> nodes will form the base layer, with the amount of nodes on each subsequent layer being _halfed_, until all nodes have been assigned:

![Image that visualizes how the space inside the container gets distributed between 15 nodes: 8 nodes on the first layer, 4 on the second, 2 on the third, and one on the last](screenshots/01.png?raw=true "Image that visualizes how the space inside the container gets distributed between 15 nodes: 8 nodes on the first layer, 4 on the second, 2 on the third, and one on the last")

While there might be further applications, this container was primarily developed to draw **tournament brackets**. That's why it includes code to automatically draw lines that connect two nodes in one layer to one node in the following layer:

![Screenshot of a tournament bracket for 8 participants (using the same amount of nodes as the image above) where the connection lines were automaticly added) inside the container, and the automaticly drawn connection lines between those nodes](screenshots/02.png?raw=true "Screenshot of a tournament bracket for 8 participants (using the same amount of nodes as the image above) where the connection lines were automaticly added")

> [!TIP]
> Once the plugin is enabled, its documentation can be accessed directly from Godot (press ``F1`` & search for "PyramidContainer").

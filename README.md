Adds a special type of train stop called "Idle Train Stop". Trains that do not
have a valid route, or their current destination has exceeded its maximum train
limit, are automatically sent to the idle train stop(s).

Best practice is to have many idle train stops, all with a train limit of one.
This way you can build a train depot that houses idle/waiting trains, and
avoid the need for "stacker" space before each station.

![Train Depot](example.png)

show_debug_message("creating WS server");
var port = 12345
var max_clients = 10
network_set_config(network_config_connect_timeout, 10000);
network_set_config(network_config_use_non_blocking_socket, 1);
var socket = network_create_server_raw(6, port, max_clients);
show_debug_message("socket id:")
show_debug_message(socket)
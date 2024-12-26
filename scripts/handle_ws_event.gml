function ws_send(socket, msg)
{
  buffer = buffer_create(1, buffer_grow, 1)
  buffer_write(buffer, buffer_text, json_stringify(msg))
  network_send_raw(socket, buffer, buffer_tell(buffer))
  buffer_delete(buffer)
}

function build_audio(is_raw, data)
{
  if (is_raw) {
    if (first_chunk) {
      first_chunk = false
      buff = buffer_create(0, buffer_grow, 1)
    }
    var _offset = buffer_tell(data)
    var _size = buffer_get_size(data) - _offset
    buffer_copy(data, _offset, _size, buff, buffer_get_size(buff))
    return;
  }
  if (data.progress == 0) {
    // first chunk
    first_chunk = true
    // buff = buffer_base64_decode(data.chunk)
  } else if (data.progress == 1) {
    // next chunk
    // buffer_base64_decode_ext(buff, data.chunk, buffer_get_size(buff))
  } else {
    // finalize
    if (variable_instance_exists(id, "audio")) {
      audio_free_buffer_sound(audio)
      buffer_delete(audio_buff)
    }
    // TODO checksum?
    size = buffer_get_size(buff)
    show_debug_message("[DEBUG] md5 checksum: " + buffer_md5(buff, 0, size))
    audio_buff = buffer_create(size, buffer_fast, 1)
    buffer_copy(buff, 0, size, audio_buff, 0)
    buffer_delete(buff)
    if (data.stereo)
      channels = audio_stereo
    else
      channels = audio_mono
    audio = audio_create_buffer_sound(audio_buff, buffer_s16, data.rate, 0, size, channels)

    var song_count = array_length(global.song_list)
    for (i = 0; i < song_count; i++)
      global.song_list[i].preview_id = audio
  }
}

function handle_request(request)
{
  if (is_undefined(request.type)) {
    show_debug_message("[ERROR] WS request has no type")
  } else {
    switch(request.type) {
      case "ping":
        return "pong"
      break;
      case "listGlobals":
        return variable_instance_get_names(global)
      break;
      case "getGlobal":
        return variable_global_get(request.data)
      break;
      case "setGlobal":
        variable_global_set(request.data.name, request.data.value)
      break;
      case "setAudio":
        build_audio(false, request.data)
      break;
      default:
        show_debug_message("[WARN] Unknown message type:")
        show_debug_message(request.type)
      break;
    }
  }
}

function received_packet(buffer, socket)
{
  if (buffer_get_size(buffer) == 0) {
    show_debug_message("Empty WS message")
    return;
  }
  if (buffer_peek(buffer, 0, buffer_u8) == 42) {
    show_debug_message("New RAW WS message: ")
    buffer_seek(buffer, buffer_seek_start, 1)
    resp_id = buffer_read(buffer, buffer_u64)
    build_audio(true, buffer)
    
    ws_send(socket, { id: resp_id })
  } else {
    var buff_text = buffer_read(buffer, buffer_text)
    show_debug_message("New JSON WS message: ")
    show_debug_message(buff_text)
    request = json_parse(buff_text)

    // show_debug_message("New WS message: ")
    show_debug_message(request)
    if(is_undefined(id)) {
      // no id
    } else {
      ws_send(socket, {
        id: request.id,
        data: handle_request(request.data)
      })
    }
  }
}

var socket_list = ds_list_create()

var type_event = ds_map_find_value(async_load, "type")
show_debug_message("new event with type:");
show_debug_message(type_event);
switch (type_event)
{
    case network_type_connect:
        socket = ds_map_find_value(async_load, "socket")
        ds_list_add(socket_list, socket)
    break;
    
    case network_type_disconnect:
        socket = ds_map_find_value(async_load, "socket")
        ds_list_delete(socket_list, ds_list_find_index(socket_list, socket))
    break;
    
    case network_type_data:
        buffer = ds_map_find_value(async_load, "buffer")
        socket = ds_map_find_value(async_load, "id")
        buffer_seek(buffer, buffer_seek_start, 0)
        received_packet(buffer, socket)
    break;
}
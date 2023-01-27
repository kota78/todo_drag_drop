import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';
import 'package:todo_drag_drop/models/task.dart';

part 'rest_client.g.dart';

@RestApi(baseUrl: "https://api.dida365.com")
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;
  @GET("/open/v1/project/all/task/63cf5784c62f112d088f533b")
  Future<Task> getTask();

  @POST("/open/v1/task")
  Future<Task> createTask(@Body() Task task);
}

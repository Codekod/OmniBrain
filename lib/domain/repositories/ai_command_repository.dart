abstract class AiCommandRepository {
  Future<String> processCommand(String command);

  Future<List<String>> getSuggestions();

  Future<String> processTextCalculation(String text);

  Future<String> processImageCalculation(String imagePath);

  Future<String> getPomodoroSuggestion(String task);

  Future<String> askMemory(String query, List<String> notesContext);

  Future<String> processConversion(String query);
}

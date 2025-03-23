

int main(List<String> args) {
  for (String arg in args) if (arg == "--start-interface-app") return 0;

  return 0;
}
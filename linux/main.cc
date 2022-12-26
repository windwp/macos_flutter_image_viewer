#include "my_application.h"
#include <iostream>

int main(int argc, char** argv) {
  int x = 0;
  int y = 0;
  int width=10;
  int height=10;

  if(argc >= 4){
    x      = std::stoi(argv[1]);
    y      = std::stoi(argv[2]);
    width  = std::stoi(argv[3]);
    height = std::stoi(argv[4]);
  };

  g_autoptr(MyApplication) app = my_application_new(x, y, width, height);
  return g_application_run(G_APPLICATION(app), argc, argv);

}

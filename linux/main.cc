#include "my_application.h"
#include <iostream>

int main(int argc, char** argv) {
  int x = 0;
  int y = 0;
  int width=100;
  int height=100;

  if(argc >= 5){
    x      = std::stoi(argv[2]);
    y      = std::stoi(argv[3]);
    width  = std::stoi(argv[4]);
    height = std::stoi(argv[5]);
  };

  g_autoptr(MyApplication) app = my_application_new(x, y, width, height);
  return g_application_run(G_APPLICATION(app), argc, argv);

}

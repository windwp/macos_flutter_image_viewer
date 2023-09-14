#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use tauri::{ LogicalSize, Manager, PhysicalPosition, Position, Size};
use std::io::{BufRead, BufReader};
use std::net::{TcpListener};

struct ArgsValue {
    x: i32,
    y: i32,
    width: f64,
    height: f64,
    url: String,
}

// use with url like this: https://www.google.com have content-security-policy
#[tauri::command]
async fn get_html_content(url: String) -> String {
    let mut html = String::new();
    let resp = reqwest::get(&url).await;
    if let Ok(resp) = resp {
        if resp.status().is_success() {
            html =resp.text().await.unwrap();
        }
    }
    html.to_string()
}

// async fn start_server() {
//     // initialize tracing
//     let listener = TcpListener::bind("127.0.0.1:8000").unwrap();

//     // Accept incoming connections
//     for stream in listener.incoming() {
//         // Spawn a new thread for each connection
//         std::thread::spawn(move || {
//             // Read incoming data from the connection
//             let mut reader = BufReader::new(stream.unwrap());
//             let mut buffer = String::new();
//             reader.read_line(&mut buffer).unwrap();

//             // Print the incoming message
//             println!("Received message: {}", buffer.trim());
//         });
//     }
// }

// basic handler that responds with a static string
async fn root() -> &'static str {
    "Hello, World!"
}

fn main() {
    let context = tauri::generate_context!();
    // start_server();
    tauri::Builder::default()
        .setup(|app| {
            let mut args = ArgsValue {
                x: 0,
                y: 0,
                url: String::from(""),
                width: 300.0,
                height: 300.0,
            };
            match app.get_cli_matches() {
                // `matches` here is a Struct with { args, subcommand }.
                // `args` is `HashMap<String, ArgData>` where `ArgData` is a struct with { value, occurrences }.
                // `subcommand` is `Option<Box<SubcommandMatches>>` where `SubcommandMatches` is a struct with { name, matches }.
                Ok(matches) => {
                    if let Some(x) = matches.args.get("x") {
                        if x.occurrences == 1 {
                            args.x = x.value.as_str().unwrap().parse::<i32>().unwrap();
                        }
                    }

                    if let Some(y) = matches.args.get("y") {
                        if y.occurrences == 1 {
                            args.y = y.value.as_str().unwrap().parse::<i32>().unwrap();
                        }
                    }

                    if let Some(width) = matches.args.get("width") {
                        if width.occurrences == 1 {
                            args.width = width.value.as_str().unwrap().parse::<f64>().unwrap();
                        }
                    }

                    if let Some(height) = matches.args.get("height") {
                        if height.occurrences == 1 {
                            args.height = height.value.as_str().unwrap().parse::<f64>().unwrap();
                        }
                    }

                    if let Some(url) = matches.args.get("url") {
                        if url.occurrences == 1 {
                            args.url = url.value.as_str().unwrap().to_string();
                        }
                    }
                    println!("{:?}", matches)
                }
                Err(_) => {}
            }
            let main_window = app.get_window("main").unwrap();
            main_window
                .set_position(Position::Physical(PhysicalPosition {
                    x: args.x,
                    y: args.y,
                }))
                .unwrap();
            main_window.set_decorations(false).unwrap();
            main_window
                .set_size(Size::Logical(LogicalSize {
                    width: args.width,
                    height: args.height,
                }))
                .unwrap();
            main_window.set_resizable(false).unwrap();
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![get_html_content])
        .run(context)
        .expect("error while running tauri application");
}

#![allow(non_snake_case, unused)]
use dioxus::prelude::*;
use dioxus_fullstack::prelude::*;

fn main() {
    #[cfg(feature = "ssr")]
    LaunchBuilder::new(app)
        .addr(std::net::SocketAddr::from(([0, 0, 0, 0], 8080)))
        .launch();

    #[cfg(feature = "web")]
    LaunchBuilder::new(app).launch();
}

fn app(cx: Scope) -> Element {
    cx.render(rsx! {
        div {
            "Hello, world!"
        }
    })
}

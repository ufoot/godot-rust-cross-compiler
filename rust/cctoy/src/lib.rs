use godot::prelude::*;
use godot::classes::{Label, ILabel};

struct CcToyExtension;

#[gdextension]
unsafe impl ExtensionLibrary for CcToyExtension {}

#[derive(GodotClass)]
#[class(base=Label)]
pub struct MsgLabel {
    base: Base<Label>,
}

#[godot_api]
impl ILabel for MsgLabel {
    fn init(base: Base<Label>) -> Self {
        godot_print!("MsgLabel initialized");
        MsgLabel { base }
    }

    fn ready(&mut self) {
        godot_print!("msg label is ready");
        self.base_mut().set_text(&withgodot::get_msg());
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn check_withgodot_get_msg() {
        assert_eq!("msg from Rust: 0.5", withgodot::get_msg());
    }
}

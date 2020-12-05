use gdnative::prelude::*;
use withgdnative;

#[derive(NativeClass)]
#[inherit(Label)]
pub struct MsgLabel;

#[methods]
impl MsgLabel {
    fn new(_owner: &Label) -> Self {
        MsgLabel
    }

    #[export]
    fn _ready(&self, owner: &Label) {
        godot_print!("msg label is ready");
        owner.set_text(withgdnative::get_msg());
    }
}

fn init(handle: InitHandle) {
    handle.add_class::<MsgLabel>();
}

godot_init!(init);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn check_withgdnative_get_msg() {
        assert_eq!("msg from Rust: 0.5", withgdnative::get_msg());
    }
}

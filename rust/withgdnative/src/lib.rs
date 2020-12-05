use gdnative::prelude::*;

pub fn get_msg() -> String {
    let vec = Vector2::new(1.0, 2.0);
    format!("{}: {}", purelib::get_msg(), vec.aspect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_get_msg() {
        assert_eq!("msg from Rust: 0.5", get_msg());
    }
}

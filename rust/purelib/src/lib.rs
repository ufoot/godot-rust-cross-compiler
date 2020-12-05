pub fn get_msg() -> String {
    "msg from Rust".into()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn check_get_msg() {
        assert_eq!("msg from Rust", get_msg());
    }
}

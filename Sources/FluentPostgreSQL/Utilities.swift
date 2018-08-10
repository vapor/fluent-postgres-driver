protocol AnyArray {
    static var anyElementType: Any.Type { get }
}

extension Array: AnyArray {
    static var anyElementType: Any.Type {
        return Element.self
    }
}

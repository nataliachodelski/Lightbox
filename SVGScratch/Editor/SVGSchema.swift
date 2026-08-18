import Foundation

enum SVGSchema {
    static let globalAttributes: [String] = [
        "id", "class", "style", "transform",
        "fill", "fill-opacity", "fill-rule",
        "stroke", "stroke-width", "stroke-opacity", "stroke-linecap", "stroke-linejoin",
        "stroke-dasharray", "stroke-dashoffset", "stroke-miterlimit",
        "opacity", "clip-path", "clip-rule", "mask", "filter",
        "font-family", "font-size", "font-weight", "font-style", "text-anchor",
        "visibility", "display", "color", "vector-effect",
    ]

    static let elements: [String: [String]] = [
        "svg": ["xmlns", "width", "height", "viewBox", "preserveAspectRatio", "version"],
        "g": [],
        "defs": [],
        "symbol": ["viewBox", "x", "y", "width", "height"],
        "use": ["x", "y", "width", "height", "href"],
        "switch": [],
        "a": ["href", "target"],
        "foreignObject": ["x", "y", "width", "height"],
        "title": [],
        "desc": [],
        "metadata": [],
        "style": ["type"],

        "circle": ["cx", "cy", "r"],
        "ellipse": ["cx", "cy", "rx", "ry"],
        "rect": ["x", "y", "width", "height", "rx", "ry"],
        "line": ["x1", "y1", "x2", "y2"],
        "polyline": ["points"],
        "polygon": ["points"],
        "path": ["d", "pathLength"],

        "text": ["x", "y", "dx", "dy", "rotate", "textLength", "lengthAdjust"],
        "tspan": ["x", "y", "dx", "dy", "rotate", "textLength"],
        "textPath": ["href", "startOffset"],

        "linearGradient": ["x1", "y1", "x2", "y2", "gradientUnits", "gradientTransform", "spreadMethod", "href"],
        "radialGradient": ["cx", "cy", "r", "fx", "fy", "gradientUnits", "gradientTransform", "spreadMethod", "href"],
        "stop": ["offset", "stop-color", "stop-opacity"],

        "clipPath": ["clipPathUnits"],
        "mask": ["x", "y", "width", "height", "maskUnits", "maskContentUnits"],
        "pattern": ["x", "y", "width", "height", "patternUnits", "patternContentUnits", "patternTransform", "viewBox", "href"],
        "marker": ["markerWidth", "markerHeight", "refX", "refY", "orient", "markerUnits", "viewBox"],

        "filter": ["x", "y", "width", "height", "filterUnits", "primitiveUnits"],
        "feGaussianBlur": ["in", "stdDeviation", "result"],
        "feOffset": ["in", "dx", "dy", "result"],
        "feMerge": ["result"],
        "feMergeNode": ["in"],
        "feColorMatrix": ["in", "type", "values", "result"],
        "feComposite": ["in", "in2", "operator", "result"],
        "feBlend": ["in", "in2", "mode", "result"],
        "feFlood": ["flood-color", "flood-opacity", "result"],
        "feDropShadow": ["in", "dx", "dy", "stdDeviation", "result"],
        "feTurbulence": ["type", "baseFrequency", "numOctaves", "seed", "result"],

        "animate": ["attributeName", "from", "to", "dur", "repeatCount", "values", "begin", "fill"],
        "animateTransform": ["attributeName", "type", "from", "to", "dur", "repeatCount", "begin"],
        "animateMotion": ["path", "dur", "repeatCount", "begin"],
        "set": ["attributeName", "to", "begin", "dur"],
    ]

    static var elementNames: [String] {
        Array(elements.keys)
    }

    static let enumAttributeValues: [String: [String]] = [
        "fill-rule": ["nonzero", "evenodd"],
        "clip-rule": ["nonzero", "evenodd"],
        "stroke-linecap": ["butt", "round", "square"],
        "stroke-linejoin": ["miter", "round", "bevel"],
        "text-anchor": ["start", "middle", "end"],
        "visibility": ["visible", "hidden", "collapse"],
        "display": ["inline", "none"],
        "gradientUnits": ["userSpaceOnUse", "objectBoundingBox"],
        "patternUnits": ["userSpaceOnUse", "objectBoundingBox"],
        "maskUnits": ["userSpaceOnUse", "objectBoundingBox"],
        "filterUnits": ["userSpaceOnUse", "objectBoundingBox"],
        "spreadMethod": ["pad", "reflect", "repeat"],
        "preserveAspectRatio": ["none", "xMidYMid meet", "xMidYMid slice"],
        "lengthAdjust": ["spacing", "spacingAndGlyphs"],
    ]

    static func attributes(for element: String) -> [String] {
        (elements[element] ?? []) + globalAttributes
    }
}

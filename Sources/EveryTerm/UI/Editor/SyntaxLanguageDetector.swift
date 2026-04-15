import Foundation

/// Detected syntax language for a file.
public enum SyntaxLanguage: String, Sendable {
    case shell
    case python
    case javascript
    case typescript
    case json
    case yaml
    case toml
    case xml
    case sql
    case go
    case rust
    case java
    case c
    case cpp
    case docker
    case makefile
    case config
    case plaintext
}

/// Detects syntax language from filename and checks read-only permissions.
public enum SyntaxLanguageDetector {
    private static let extensionMap: [String: SyntaxLanguage] = [
        "sh": .shell,
        "py": .python,
        "js": .javascript,
        "ts": .typescript,
        "json": .json,
        "yaml": .yaml,
        "yml": .yaml,
        "toml": .toml,
        "xml": .xml,
        "sql": .sql,
        "go": .go,
        "rs": .rust,
        "java": .java,
        "c": .c,
        "h": .c,
        "cpp": .cpp,
        "conf": .config,
    ]

    private static let filenameMap: [String: SyntaxLanguage] = [
        "Dockerfile": .docker,
        "Makefile": .makefile,
    ]

    /// Detect syntax language from a filename.
    public static func detect(filename: String) -> SyntaxLanguage {
        // Check special filenames first
        if let language = filenameMap[filename] {
            return language
        }

        // Check extension
        let ext = (filename as NSString).pathExtension
        if !ext.isEmpty, let language = extensionMap[ext] {
            return language
        }

        return .plaintext
    }

    /// Check if a file is read-only based on Unix permissions.
    public static func isReadOnly(permissions: UInt32) -> Bool {
        return (permissions & 0o200) == 0
    }
}

import Foundation

/// Raccourci de localisation. Les chaînes vivent dans
/// Resources/{en,fr}.lproj/Localizable.strings, copiées dans le bundle au build.
/// L'anglais est la langue par défaut ; macOS choisit selon la langue système.
func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

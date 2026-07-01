import Foundation

enum Config {
    static let supabaseURL: URL = loadURL("SUPABASE_URL")
    static let supabaseAnonKey: String = loadString("SUPABASE_ANON_KEY")

    private static func loadString(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let value = dict[key] as? String,
              !value.isEmpty,
              !value.hasPrefix("YOUR_") else {
            fatalError("Missing or placeholder value for \(key) in Config.plist. Copy Config.template.plist to Config.plist and fill in your Supabase credentials.")
        }
        return value
    }

    private static func loadURL(_ key: String) -> URL {
        let string = loadString(key)
        guard let url = URL(string: string) else {
            fatalError("Invalid URL for \(key) in Config.plist: \(string)")
        }
        return url
    }
}

//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by apple on 16/05/21.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject{
    let id: UUID
    static let palette: String = "🍉🍅🍋💽🛴🚓🥎⛳️🦊"
    @Published private var emojiArt: EmojiArt {
        didSet{
            // here also we can save instead of the sink in init method
        }
    }
    @Published private(set) var backgroundImage: UIImage?
    @Published var steadyStateZoomScale: CGFloat = 1.0
    @Published var steadyStatePanOffset: CGSize = .zero
    
    var emojis: [EmojiArt.Emoji]{emojiArt.emojis}
    private var autoSaveCancellable: AnyCancellable?// type erased version of Cancellable
    private var fetchImageCancellable : AnyCancellable?
    var url: URL?{
        didSet{
            self.save(self.emojiArt)
        }
    }
    
    init(id: UUID? = nil){
        self.id = id ?? UUID()
        let defaultsKey = "EmojiArtDocument.\(self.id.uuidString)"
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: defaultsKey)) ?? EmojiArt()
        autoSaveCancellable = $emojiArt.sink{ emojiArt in
            UserDefaults.standard.setValue(emojiArt.json, forKey: defaultsKey)
        }
        fetchBackgroundImageData()
    }
    
    init(url: URL){
        self.id = UUID()
        self.url = url
        self.emojiArt = EmojiArt(json: try? Data(contentsOf: url)) ?? EmojiArt()
        fetchBackgroundImageData()
        autoSaveCancellable = $emojiArt.sink{ emojiArt in
            self.save(emojiArt)
        }
    }
    
    private func save(_ emojiArt: EmojiArt){
        guard let url = url else {return}
        try? emojiArt.json?.write(to: url)
    }
    
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat){
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize)  {
        if let index = emojiArt.emojis.firstIndex(matching: emoji){
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat){
        if let index = emojiArt.emojis.firstIndex(matching: emoji){
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    
    var backgroundUrl: URL?{
        get {
            emojiArt.backgroundURL
        }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
    }
    
    private func fetchBackgroundImageData(){
        backgroundImage = nil
        if let url = self.emojiArt.backgroundURL?.imageURL {
            fetchImageCancellable?.cancel()
            fetchImageCancellable = URLSession.shared.dataTaskPublisher(for: url)
                .map {data, urlResponse in UIImage(data: data)}
                .receive(on: DispatchQueue.main)
                .replaceError(with: nil)
                .assign(to: \.backgroundImage, on: self)
//            let session = URLSession.shared
//            let publisher = session.dataTaskPublisher(for: url)
//                .map {data, urlResponse in UIImage(data: data)}
//                .receive(on: DispatchQueue.main)
//                .replaceError(with: nil)
//            fetchImageCancellable = publisher.assign(to: \.backgroundImage, on: self)
            
        }
    }
}
extension EmojiArt.Emoji{
    var fontSize: CGFloat{CGFloat(self.size)}
    var location: CGPoint{ CGPoint(x: CGFloat(x), y: CGFloat(y))}
}
extension EmojiArtDocument : Hashable, Identifiable{
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

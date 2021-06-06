//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by apple on 16/05/21.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    @GestureState private var gesturePanOffset: CGSize = .zero
    @State private var choosenPalette: String = ""
    @State private var explainBackgroundPaste = false
    @State private var confirmBackgroundPaste = false
    @State private var showImagePicker = false
    @State private var imagePickerSourceType = UIImagePickerController.SourceType.photoLibrary
    
    init(document: EmojiArtDocument){
        self.document = document
        //can't do directly this
        //choosenPalette = document.defaultPalette
        _choosenPalette = State(wrappedValue: self.document.defaultPalette)
    }
    
    var isLoading: Bool{
        document.backgroundUrl != nil && document.backgroundImage == nil
    }
    
    private var zoomScale: CGFloat{
        document.steadyStateZoomScale * gestureZoomScale
    }
    
    private var panOffset: CGSize{
        (document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    var body: some View {
        VStack{
            HStack{
                PaletteChooser(document: document, choosenPalette: $choosenPalette)
                ScrollView(.horizontal) {
                    HStack{
                        ForEach(choosenPalette.map{String($0)}, id: \.self){ emoji in
                            Text(emoji)
                                .font(Font.system(size: defaultEmojiSize))
                                .onDrag {return NSItemProvider(object: emoji as NSString)}
                        }
                    }
                }
                //.onAppear{choosenPalette = document.defaultPalette}
            }
            GeometryReader { geometry in
                ZStack{
                    Rectangle().foregroundColor(.yellow).overlay(
                        Group{
                            if self.document.backgroundImage != nil{
                                Image(uiImage: self.document.backgroundImage!)
                            }
                        }.scaleEffect(self.zoomScale)
                        .offset(self.panOffset)
                    ).gesture(self.doubleTapZoom(in:geometry.size))
                    if self.isLoading {
                        Image(systemName: "hourglass").imageScale(.large).spinning()
                    }else {
                        ForEach(self.document.emojis){ emoji in
                            Text(emoji.text)
                                .font(self.font(for: emoji))
                                .position(self.position(for: emoji, in: geometry.size))
                        }
                    }
                }.clipped()
                .gesture(self.panGesture())
                .gesture(self.zoomGesture())
                .edgesIgnoringSafeArea([.horizontal,.bottom])
                .onReceive(document.$backgroundImage) { image in
                    zoomToFit(image, in: geometry.size)
                }
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) {providers, location in
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x-self.panOffset.width, y: location.y - self.panOffset.height)
                    location = CGPoint(x: location.x / self.zoomScale, y: location.y / zoomScale)
                    return self.drop(providers: providers, at: location)
                }
                .navigationBarItems(leading: pickImage, trailing: Button(action: {
                    if let url = UIPasteboard.general.url, url != document.backgroundUrl{
                        confirmBackgroundPaste = true
                    }else{
                        explainBackgroundPaste = true
                    }
                }, label: {
                    Image(systemName: "doc.on.clipboard").imageScale(.large)
                        .alert(isPresented: $explainBackgroundPaste){
                            return Alert(title: Text("Paste Background"), message: Text("Copy the URL of an image to the clip board and touch this button to make it the background of your document."), primaryButton: .default(Text("OK")){
                                document.backgroundUrl = UIPasteboard.general.url
                            }, secondaryButton: .cancel())
                        }
                }))
                .zIndex(-1)
            }.alert(isPresented: $confirmBackgroundPaste){
                return Alert(title: Text("Paste Background"), message: Text("Replace your background with \(UIPasteboard.general.url?.absoluteString ?? "nothing")?."), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private var pickImage: some View{
        HStack{
            Image(systemName: "photo").imageScale(.large).foregroundColor(.accentColor).onTapGesture {
                imagePickerSourceType = .photoLibrary
                showImagePicker = true
            }
            if UIImagePickerController.isSourceTypeAvailable(.camera){
                Image(systemName: "camera").imageScale(.large).foregroundColor(.accentColor).onTapGesture {
                    imagePickerSourceType = .camera
                    showImagePicker = true
                }
            }
        }
        .sheet(isPresented: $showImagePicker){
            ImagePicker(sourceType: imagePickerSourceType){ image in
                if image != nil{
                    DispatchQueue.main.async {
                        self.document.backgroundUrl = image!.storeInFilesystem()
                    }
                }
                self.showImagePicker = false
            }
        }
    }
    
    private func doubleTapZoom(in size: CGSize) -> some Gesture{
        TapGesture(count: 2)
            .onEnded { (_) in
                withAnimation{
                    self.zoomToFit(self.document.backgroundImage
                               , in: size)
                }
            }
    }
    
    private func zoomGesture() -> some Gesture{
        MagnificationGesture()
            .updating($gestureZoomScale){latestGestureScale, gestureZoomScale , transaction in
                gestureZoomScale  = latestGestureScale
            }
            .onEnded { (finalGestureScale) in
                self.document.steadyStateZoomScale *= finalGestureScale
            }
    }
    
    private func panGesture() -> some Gesture{
        DragGesture()
            .updating($gesturePanOffset){ latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
            }
            .onEnded{ finalGestureValue in
                self.document.steadyStatePanOffset = self.document.steadyStatePanOffset + (finalGestureValue.translation / self.zoomScale)
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize){
        if let image = image, image.size.width > 0, image.size.height > 0 , size.height > 0, size.width > 0{
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            self.document.steadyStatePanOffset = .zero
            self.document.steadyStateZoomScale = min(hZoom,vZoom)
        }
    }
    
    private func font(for emoji: EmojiArt.Emoji) -> Font{
        Font.system(size: emoji.fontSize * zoomScale)
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint{
        var location = emoji.location
        location = CGPoint(x: location.x / self.zoomScale, y: location.y / zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + self.panOffset.width, y: location.y + self.panOffset.height)
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { (url) in
            print("dropped \(url)")
            self.document.backgroundUrl = url
        }
        if !found{
            found = providers.loadFirstObject(ofType: String.self) { string in
                document.addEmoji(string, at: location, size: defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

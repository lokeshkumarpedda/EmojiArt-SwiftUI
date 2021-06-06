//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by apple on 23/05/21.
//

import SwiftUI

struct PaletteChooser: View {
    @ObservedObject var document: EmojiArtDocument
    @Binding  var choosenPalette: String
    @State private var showPaletteEditor = false
    
    var body: some View {
        HStack{
            Stepper(
                onIncrement: {self.choosenPalette = document.palette(after: self.choosenPalette)},
                onDecrement: { self.choosenPalette = document.palette(before: self.choosenPalette) },
                label: {
                    EmptyView()
                })
            Text(document.paletteNames[self.choosenPalette] ?? "")
            Image(systemName: "keyboard").imageScale(.large)
                .onTapGesture {
                    showPaletteEditor = true
                }
                .popover(isPresented: $showPaletteEditor){
                    PaletteEditor(choosenPalette: $choosenPalette, showPaletteEditor: $showPaletteEditor)
                        .environmentObject(document)
                        .frame(minWidth:300, minHeight: 500)
                }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
struct PaletteEditor: View{
    @EnvironmentObject var document: EmojiArtDocument
    @Binding var choosenPalette: String
    @State var paletteName: String = ""
    @State var emojiToAdd: String = ""
    @Binding var showPaletteEditor: Bool
    
    var height: CGFloat{
        CGFloat((choosenPalette.count - 1) / 6) * 70 + 70
    }
    let  fontSize: CGFloat = 40
    var body : some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Palette Editor").font(.headline).padding()
                HStack{
                    Spacer()
                    Button(action: {
                        showPaletteEditor = false
                    }, label:{ Text("Done")})
                }
            }
            Divider()
            Form{
                Section{
                    TextField("Palette Name", text: $paletteName, onEditingChanged:{began in
                        if !began {
                            document.renamePalette(choosenPalette, to: paletteName)
                        }
                    })
                    TextField("Add Emoji", text: $emojiToAdd, onEditingChanged:{began in
                        if !began {
                            choosenPalette = document.addEmoji(emojiToAdd, toPalette: choosenPalette)
                            emojiToAdd = ""
                        }
                    })
                }
            }
            Section(header: Text("Remove Emoji")){
                Grid(choosenPalette.map{String($0)}, id : \.self){ emoji in
                    Text(emoji).font(Font.system(size: fontSize))
                        .onTapGesture {
                            choosenPalette = document.removeEmoji(emoji, fromPalette: choosenPalette)
                        }
                }.frame(height: height)
                
            }
        }
        .onAppear{paletteName = document.paletteNames[self.choosenPalette] ?? ""}
    }
    
    
}

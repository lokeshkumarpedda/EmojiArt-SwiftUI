//
//  EmojiDocumentChooser.swift
//  EmojiArt
//
//  Created by apple on 23/05/21.
//

import SwiftUI

struct EmojiDocumentChooser: View {
    @EnvironmentObject var store: EmojiArtDocumentStore
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView{
            List {
                ForEach(store.documents){ document in
                    NavigationLink(destination: EmojiArtDocumentView(document: document)
                                    .navigationBarTitle(store.name(for: document))){
                        EditableText(store.name(for: document), isEditing: editMode.isEditing){name in
                            store.setName(name, for: document)
                        }
                    }
                }
                .onDelete{ indexset in
                    indexset.map { self.store.documents[$0] }.forEach{document in
                        self.store.removeDocument(document)
                    }
                }
            }
            .navigationBarTitle(store.name)
            .navigationBarItems(leading: Button(action: {
                store.addDocument()
            }, label: {
                Image(systemName: "plus").imageScale(.large)
            }),
            trailing: EditButton()
            )
            .environment(\.editMode, $editMode)
        }
    }
}

struct EmojiDocumentChooser_Previews: PreviewProvider {
    static var previews: some View {
        EmojiDocumentChooser()
    }
}

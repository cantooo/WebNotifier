//
//  ContentView.swift
//  WebNotifier
//
//  Created by Simone Cantoni on 05/04/21.
//

import SwiftUI

//  Storage system for saving URLs and HTMLs
let userDefaults = UserDefaults.standard
let urlsKey = "WebNotifierUrls"
let htmlsKey = "WebNotifierHTMLs"

//  Clipboard functionality for copying URLs in list
let pasteboard = UIPasteboard.general

//  Operation Queue for inapp threading
let operationQueue = OperationQueue()

struct ContentView: View {
//  URL TextField
    @State var input = ""
//  URLs saved in storage
    @State var urls = userDefaults.stringArray(forKey: urlsKey) ?? []
//  HTMLs saved in storage
    @State var htmls = userDefaults.stringArray(forKey: htmlsKey) ?? []
//  Incorrect URL Alert trigger
    @State var incorrectUrlAlert = false
//  URL already in List trigger
    @State var URLAlreadyInListAlert = false
//  Changed URL Alert trigger
    @State var changedUrlAlert = false
//  No URL changed Alert trigger
    @State var noUrlChangedAlert = false
//  The changed URL or URLs
    @State var changedUrl = ""
    
//  Hides the keyboard. There is no native way of doing this, unless like this
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
//  Tries to add the given URL into the List
    func addURL() {
//      Formats the URL trimming whitespaces and lowercases it
        let url = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
//      Resets the URL TextField
        input = ""
        
//      If the URL is correctly given
        if !url.isEmpty {
//          If the given URL is not already in List
            if !urls.contains(url) {
//              Fetch the HTML at the given url. If it returns `nil`, default value is ""
                let html = fetchHTML(at: url) ?? ""
//              If the URL is incorrect (the fetch returned `nil`)
                if html == "" {
//                  Show the incorrect URL Alert
                    incorrectUrlAlert.toggle()
                } else {
//                  Add the URL to the list of saved URLs and synchronize storage
                    urls.append(url)
                    userDefaults.set(urls, forKey: urlsKey)
//                  Add the HTML to the list of fetched HTMLs and synchronize storage
                    htmls.append(html)
                    userDefaults.set(htmls, forKey: htmlsKey)
                }
            } else {
//              Show the URL already in List Alert
                URLAlreadyInListAlert.toggle()
            }
        }
    }
    
//  Fetches the HTML of the webpage at the given url
    func fetchHTML (at url: String)->String? {
        var html = ""
        
//      Tries to fetch the HTML at the given URL
        do {
            html = try String(contentsOf: URL(string: url)!)
        } catch let error {
//          If an error is found it returns `nil`
            print(error.localizedDescription)
            print("Non sono riuscito a caricare la pagina", url, ".")
            return nil
        }
        
        return html
    }
    
//  Fetches every HTML of every URL and checkes for changes, appearing as an inapp Alert.
//  Dynamic webpages will always appear as changed, because of several changing session-unique IDs when fetching
    func checkChangesInApp() {
        if urls.count == 0 {
            return
        }
        
        changedUrl = ""
        
//      For every element in urls
        for i in 0..<urls.count {
//          Sets the url
            let url = urls[i]
//          Sets the old HTML
            let htmlOld = htmls[i]
//          Fetch the HTML of the page
            let htmlNew = fetchHTML(at: url) ?? ""
            
//          If the fetch did happen correctly and the webpage is changed
            if htmlNew != "" && htmlNew != htmlOld {
//              Saves the new HTML and synchronize storage
                htmls[i] = htmlNew
                userDefaults.set(htmls, forKey: htmlsKey)
                
//              Adds this url to list of URLs that changed
                changedUrl += "\(url), "
            }
        }
        
//      If there is at least 1 changed URL, eliminates the ", " string at the end. Then shows the changed URL alert
        if changedUrl != "" {
            changedUrl.popLast()
            changedUrl.popLast()
            changedUrlAlert.toggle()
        } else {
//      Else it notifies the user about no URL changed
            noUrlChangedAlert.toggle()
        }
    }
    
    var body: some View {
//      For the bold title
        NavigationView(content: {
//          Elements structure
            Form(content: {
//              First section
                Section(header: Text("INSERIMENTO")) {
//                  URL TextField
                    TextField("URL da controllare", text: $input).disableAutocorrection(true)
                        .alert(isPresented: $incorrectUrlAlert) {
//                          Incorrect URL Alert
                            Alert(title: Text("URL errato"), message: Text("L'URL fornito non sembra corrispondere a un URL valido. Controlla che l'URL sia giusto e che tu sia connesso a internet."), dismissButton: .default(Text("Ok")))
                        }
                    Button {
//                      Hides the keyboard
                        hideKeyboard()
                        
//                      Tries to add the given URL into the List
                        operationQueue.addOperation {self.addURL()}
                    } label: {
                        HStack{
                            Text("Inizia a controllare")
                            Spacer()
                            Label("", systemImage: "link.badge.plus")
                        }
                    }.alert(isPresented: $URLAlreadyInListAlert) {
                        Alert(title: Text("URL già inserito"), message: Text("L'URL fornito è già nella lista."), dismissButton: .default(Text("Ok")))
                    }
                }
//              Second section
                Section(header: Text("CONTROLLO IN CORSO")) {
//                  Button that checks changes between current HTML and last stored HTML
                    Button {
                        operationQueue.addOperation {self.checkChangesInApp()}
                    } label: {
                        HStack{
                            Text("Controlla modifiche")
                            Spacer()
                            Label("", systemImage: "network")
                        }
                    }.alert(isPresented: $changedUrlAlert, content: {
//                      Changed URL or URLs Alert
                        Alert(title: Text("La pagina è cambiata"), message: Text("La pagina \(changedUrl) è cambiata."), dismissButton: .default(Text("Ok")))
                    })
//                  List of all stored URLs
                    List{
//                      For each URL in `urls` array
                        ForEach(urls, id: \.self) { url in
//                          List item with the url
                            Text(url)
//                              Context menu (long press)
                                .contextMenu {
                                    Button {
//                                      Tries to open the url into the default browser
                                        if let url = URL(string: url) {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
//                                      Button text with icon
                                        Label("Apri", systemImage: "safari")
                                    }
                                    Button {
                                        pasteboard.string = url
                                    } label: {
                                        Label("Copia", systemImage: "doc.on.doc")
                                    }
                                }
//                      Slide to the left to delete an element
                        }.onDelete(perform: { indexSet in
//                          Removes URL from array and synchronize storage
                            urls.remove(atOffsets: indexSet)
                            userDefaults.set(urls, forKey: urlsKey)
//                          Removes HTML from array and synchronize storage
                            htmls.remove(atOffsets: indexSet)
                            userDefaults.set(htmls, forKey: htmlsKey)
                        })
                    }.alert(isPresented: $noUrlChangedAlert, content: {
                        Alert(title: Text("Nessuna modifica"), message: Text("Ho controllato gli URL e non ho trovato modifiche alle pagine web."), dismissButton: .default(Text("Ok")))
                    })
                }
            })
//          Bold title on top
            .navigationTitle("WebNotifier")
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

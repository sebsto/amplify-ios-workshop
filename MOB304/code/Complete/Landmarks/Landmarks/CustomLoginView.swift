import SwiftUI
import Combine

// Scroll the view when the keyboard appears
// thanks to https://www.vadimbulavin.com/how-to-move-swiftui-view-when-keyboard-covers-text-field/
struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(Publishers.keyboardHeight) { self.keyboardHeight = $0 }
            .animation(.easeOut(duration: 0.5))
    }
}

extension View {
    func keyboardAdaptive() -> some View {
        ModifiedContent(content: self, modifier: KeyboardAdaptive())
    }
}

extension Publishers {
    // 1.
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        // 2.
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        // 3.
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}


struct CustomLoginView : View {
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    private let app = UIApplication.shared.delegate as! AppDelegate

    var body: some View { // The body of the screen view
        VStack {
            Image("turtlerock")
            .resizable()
            .aspectRatio(contentMode: ContentMode.fit)
            .padding(Edge.Set.bottom, 20)
            
            Text(verbatim: "Login").bold().font(.title)
            
            Text(verbatim: "Explore Landmarks of the world")
            .font(.subheadline)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 70, trailing: 0))
                                
            TextField("Username", text: $username)
            .autocapitalization(.none) //avoid autocapitalization of the first letter
            .padding()
            .cornerRadius(4.0)
            .background(Color(UIColor.systemFill))
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0))
            
            SecureField("Password", text: $password)
            .padding()
            .cornerRadius(4.0)
            .background(Color(UIColor.systemFill))
            .padding(.bottom, 10)

            Button(action: { self.app.signIn(username: self.username, password: self.password) }) {
                HStack() {
                    Spacer()
                    Text("Signin")
                        .foregroundColor(Color.white)
                        .bold()
                    Spacer()
                }
                                
            }.padding().background(Color.green).cornerRadius(4.0)
        }.padding()
        .keyboardAdaptive() // Apply the scroll on keyboard height
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
static var previews: some View {
        CustomLoginView() // Renders your UI View on the XCode preview
    }
}
#endif

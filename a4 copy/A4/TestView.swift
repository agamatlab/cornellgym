import SwiftUI
import SDWebImageSwiftUI

struct GifView: View {
    // Use your endpoint directly as the image URL
    
    
    var body: some View {
        VStack {

            Text("Status: Using direct endpoint as GIF source")
                .padding()
                .background(Color.yellow.opacity(0.3))
                .cornerRadius(8)
        }
        .padding()
    }
}

class GifView_Previews: PreviewProvider {
    static var previews: some View {
        GifView()
    }
}

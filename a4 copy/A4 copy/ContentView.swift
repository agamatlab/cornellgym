import SwiftUI
import Combine

// Make this a class that conforms to ObservableObject
class ExerciseStore: ObservableObject {
    
    @Published var exercises: [Exercise] = []
    
    // Optional initializer to populate with initial data
    init(exercises: [Exercise] = []) {
        self.exercises = exercises
    }
}

struct ContentView: View {
    @EnvironmentObject var exercises: ExerciseStore
    
    var body: some View {
        NavigationView {
            
            ZStack{
                Color.black.edgesIgnoringSafeArea(.all)
                
                Text("Hello, World")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
                
        }
        
        

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

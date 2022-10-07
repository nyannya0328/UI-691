//
//  Home.swift
//  UI-691
//
//  Created by nyannyan0328 on 2022/10/07.
//

import SwiftUI

struct Home: View {
    @State var testCount : CGFloat = 0
    @StateObject var model : DynamicProgress = .init()
    var body: some View {
        
        Button("\(model.isAdded ? "Stop" : "Start") PROGRESS"){
            
            if model.isAdded{
                
                model.removeProgreessWithAnimations()
                
            }
            else{
                
                let config = ProgressConfig(title: "ABC", progressImage: "arrow.up", expandedImage: "clock.badge.checkmark.fill", tint: .yellow,rotationEnabled: true)
                
                
                model.addProgreessView(config: config)
                
            }
            
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity,alignment: .top)
        .padding(.top,60)
        .onReceive(Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()) { _ in
            
            if model.isAdded{
                
                testCount += 0.5
                
                model.updateProgressView(to: testCount / 100)
                
            }
            else{
                testCount = 0
            }
            
        }
        .statusBarHidden(model.hideStatuBar)
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class DynamicProgress : NSObject,ObservableObject{
    
    
    @Published var isAdded : Bool = false
    @Published var hideStatuBar : Bool = false
    
    
    func addProgreessView(config : ProgressConfig) {
        
        if rootController().view.viewWithTag(1009) == nil{
            
            let swiftUiView = DyanamicProgressView(config: config).environmentObject(self)
            
            let hotingView = UIHostingController(rootView: swiftUiView)
            
            hotingView.view.frame = screenSize()
            hotingView.view.backgroundColor = .clear
            hotingView.view.tag = 1009
            
            rootController().view.addSubview(hotingView.view)
            
            isAdded = true
        }
        
    }
    
    func removeProgreessWithAnimations(){
        
        NotificationCenter.default.post(name: NSNotification.Name("CLOSE_UPDATE"), object: nil)
        
    }
    
    func removeProgressView(){
        
        if let view = rootController().view.viewWithTag(1009){
            
            view.removeFromSuperview()
            isAdded = false
        
        }
        
    }
    
    
    
    func screenSize()->CGRect{
        
        guard let window = UIApplication.shared.connectedScenes.first as? UIWindowScene else{return .zero}
        
        return window.screen.bounds
    }
    
    func rootController()->UIViewController{
        
        guard let window = UIApplication.shared.connectedScenes.first as? UIWindowScene else{return .init()}
        
        guard let root = window.windows.first?.rootViewController else{return .init()}
        
        return root
        
    }
    
    func updateProgressView(to : CGFloat){
        
        NotificationCenter.default.post(name: NSNotification.Name("UPDATE_PROGRESS"), object: nil,userInfo: [
        
            
            "progress" : to
        
        
        ])
    }
    
    
    
    
}

struct DyanamicProgressView : View{
    
    var config : ProgressConfig
    @State var showProgresView : Bool = false
    
    @State var progress : CGFloat = 0
    @EnvironmentObject var model : DynamicProgress
    
    @State var showAlretView : Bool = false
    
    var body: some View{
        
        Canvas { cxt, size in
            
           
            cxt.addFilter(.alphaThreshold(min: 0.5,color: .black))
            cxt.addFilter(.blur(radius: 5.5))
            cxt.drawLayer { content in
                
                for index in [1,2]{
                    
                    if let resolvedImage = content.resolveSymbol(id: index){
                        
                        content.draw(resolvedImage, at: CGPoint(x: size.width / 2, y:11 + 18))
                    }
                }
            }
            
        } symbols: {
            
            ProgressConmonents()
                .tag(1)
            
            ProgressConmonents(isCircle:true)
                .tag(2)
        
        }
        .overlay(alignment: .top) {
            
            ProgreeView()
                .offset(y:11)
        }
        .overlay(alignment: .top) {
            
            CustomAlretView()
        }
        .ignoresSafeArea()
        .allowsTightening(false)
        .onAppear{
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                
                showProgresView = true
                
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CLOSE_UPDATE")), perform: { _ in
            showProgresView = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6){
                
                model.removeProgressView()
                
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UPDATE_PROGRESS"))) { output in
            
            if let info = output.userInfo,let progress = info["progress"] as? CGFloat{
                
                if progress < 1.0{
                    
                    self.progress = progress
                    
                    if (progress * 100).rounded() == 100.0{
                        
                        showProgresView = false
                        showAlretView = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                            
                            model.hideStatuBar = true
                            
                        }
                        
                        
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                            
                            showAlretView = false
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                                
                                model.hideStatuBar = false
                                
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6){
                                
                                model.removeProgressView()
                                
                                
                            }
                            
                        }
                        
                    }
                }
                
            }
            
        }
       
       

    }
    @ViewBuilder
    func CustomAlretView()->some View{
        
        GeometryReader{
            
            let size = $0.size
            
            Capsule()
                .fill(.black)
                .frame(width: showAlretView ? size.width : 125,height: showAlretView ? size.height : 35)
                .overlay {
                    
                    HStack(spacing: 13) {
                        
                        Image(systemName: config.expandedImage)
                            .symbolRenderingMode(.multicolor)
                            .font(.largeTitle)
                            .foregroundStyle(.white,.red,.green)
                        
                        
                        HStack(spacing: 6) {
                            
                              Text("Download")
                                .font(.system(size: 15).weight(.semibold))
                                .foregroundColor(.white)
                            
                            
                            Text(config.title)
                                .font(.system(size: 12).weight(.semibold))
                                .foregroundColor(.white)
                            
                        }
                        .lineLimit(1)
                        .contentTransition(.opacity)
                          .frame(maxWidth: .infinity,alignment: .leading)
                          .offset(y:12)
                        
                        
                    }
                    .padding(.horizontal,12)
                    .blur(radius: showAlretView ? 0 : 5)
                    .opacity(showAlretView ? 1 : 0)
                    
                }
            .frame(maxWidth: .infinity, maxHeight: .infinity,alignment: .top)
            
            
        }
        .frame(height: 65)
        .padding(.horizontal,19)
        .offset(y:showAlretView ? 11 : 12)
        .animation(.interactiveSpring(response: 0.6,dampingFraction: 0.7, blendDuration: 0.7).delay(showAlretView ? 0.35 : 0), value: showAlretView)
        
        
    }
    
    @ViewBuilder
    func ProgreeView ()->some View{
        
        
        ZStack{
            
            let rotation = (progress > 1 ? 1 : (progress < 0 ? 0 : progress))
            
            Image(systemName: config.progressImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .fontWeight(.semibold)
                 .frame(width: 12,height: 12)
                 .foregroundColor(config.tint)
                 .rotationEffect(.init(degrees: config.rotationEnabled ? Double(rotation * 360) : 0))
            
            
            ZStack{
                
                Circle()
                    .stroke(.white.opacity(0.25),lineWidth: 4)
                
                Circle()
                    .trim(from: 0,to: progress)
                    .stroke(config.tint,style: StrokeStyle(lineWidth: 4,lineCap: .round,lineJoin: .round))
                    .rotationEffect(.init(degrees: -90))
                
                
                
            }
             .frame(width: 23,height: 23)
            
        }
        .frame(width: 37,height: 37)
        .frame(width: 126,alignment: .trailing)
        .offset(x:showProgresView ? 45 : 0)
        .opacity(showProgresView ? 1 : 0)
        .animation(.interactiveSpring(response: 0.6,dampingFraction: 0.7, blendDuration: 0.7), value: showProgresView)
        
        
    }
    @ViewBuilder
    func ProgressConmonents (isCircle : Bool = false)->some View{
        
        if isCircle{
            
            Circle()
             .fill(.black)
             .frame(width: 37,height: 37)
             .frame(width: 126,alignment: .trailing)
             .offset(x:showProgresView ? 45: 0)
             .scaleEffect(showProgresView ? 1 : 0.55,anchor: .trailing)
             .animation(.interactiveSpring(response: 0.6,dampingFraction: 0.7, blendDuration: 0.7), value: showProgresView)
            
        }
        else{
            
            Capsule()
             .fill(.black)
             .frame(width: 126,height: 36)
             .offset(y:1)
            
        }
        
        
    }
}

import SwiftUI
import PhotosUI
import Kingfisher
import SwiftyCrop

struct AvatarView: View {
    let imageUrl: URL?
    @Binding var localImage: UIImage?
    let size: CGFloat
    let editable: Bool
    let onImageChanged: ((UIImage?) -> Void)?
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageToCrop: UIImage?
    @State private var showPhotosPicker = false
    @State private var showCropper = false
    
    init(imageUrl: URL? = nil,
         localImage: Binding<UIImage?> = .constant(nil),
         size: CGFloat = 100,
         editable: Bool = false,
         onImageChanged: ((UIImage?) -> Void)? = nil) {
        self.imageUrl = imageUrl
        self._localImage = localImage
        self.size = size
        self.editable = editable
        self.onImageChanged = onImageChanged
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat = 1024) -> UIImage {
        let size = image.size
        let widthRatio = maxDimension / size.width
        let heightRatio = maxDimension / size.height
        let scale = min(widthRatio, heightRatio)
        
        if scale >= 1.0 { return image }
        
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }
    
    var body: some View {
        ZStack {
            // Отображение аватара
            if let localImage = localImage {
                Image(uiImage: localImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let imageUrl = imageUrl {
                KFImage(imageUrl)
                    .placeholder {
                        ProgressView()
                            .frame(width: size, height: size)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                defaultPlaceholder
            }
            
            // Кнопка удаления (новая)
                if editable && localImage != nil {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                localImage = nil
                                onImageChanged?(nil)
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: size * 0.15))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2)
                            }
                            .offset(x: size * 0.1, y: -size * 0.1)
                        }
                        Spacer()
                    }
                    .frame(width: size, height: size)
                }
            
            // Кнопка редактирования
            if editable {
                Color.black.opacity(0.3)
                    .clipShape(Circle())
                    .overlay(
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .font(.system(size: size * 0.3))
                    )
            }
        }
        .frame(width: size, height: size)
        .onTapGesture {
            if editable {
                showPhotosPicker = true
            }
        }
        // Пикер для выбора фото
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        // Уменьшаем изображение перед кропом
                        let resizedImage = resizeImage(image)
                        imageToCrop = resizedImage
                        showCropper = true
                    }
                }
            }
        }
        // Модальное окно с кадрированием
        .sheet(isPresented: $showCropper) {
            if let image = imageToCrop {
                let screenSize = UIScreen.main.bounds.width
                let config = SwiftyCropConfiguration(
                    maxMagnificationScale: 8.0,   // Максимальное увеличение
                    maskRadius: screenSize * 0.45, // Кружок стал больше (чуть меньше половины экрана)
                    zoomSensitivity: 2.0,         // Скорость масштабирования
                )
                
                SwiftyCropView(
                    imageToCrop: image,
                    maskShape: .circle,
                    configuration: config,
                    onComplete: { croppedImage in
                        if let croppedImage = croppedImage {
                            localImage = croppedImage
                            onImageChanged?(croppedImage)
                        }
                        imageToCrop = nil
                        showCropper = false
                    }
                )
            }
        }
    }
    
    // Заглушка по умолчанию
    private var defaultPlaceholder: some View {
        Circle()
            .fill(Color(hex: "8B5CF6").opacity(0.3))
            .frame(width: size, height: size)
    }
}

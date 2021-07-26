
import Foundation
import UIKit
import RxSwift
import RxCocoa


struct Resource<T> {
    let url:URL
}

extension URLRequest{
    static func load<T:Decodable>(resourse: Resource<T>)->Observable<T>{
        return Observable.from([resourse.url])
            .flatMap{ url -> Observable<Data> in
                let request = URLRequest(url: url)
                return URLSession.shared.rx.data(request: request)
            }.map{data -> T in
                return try JSONDecoder().decode(T.self,from:data)
                
            }.asObservable()
    }
}

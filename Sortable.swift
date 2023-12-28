//
//  Sortable.swift
//
//  Created by pjy on 2023/12/06.
//

import Foundation

typealias Comparator<T> = (T, T) -> Bool?

protocol Sortable: Codable {
    static var sorters: Array<Sorter<Self>> { get }
}

// 오름차순, 내림차순 Enum
enum SortOrder: Codable {
    case ASC, DESC
}

// Boolean 비교 확장
extension Bool: Comparable {
    public static func < (lhs: Bool, rhs: Bool) -> Bool {
        return !lhs /* 0 */ && rhs /* 1 */
    }
}

// Raw Value가 비교 가능한 Enum에 대하여 비교 확장
extension RawRepresentable where RawValue: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension Comparable {
    func compare(to: Self, order: SortOrder = .ASC) -> Bool? {
        return to == self ? nil : order == .ASC ? self < to : to < self
    }
}

extension Sortable {
    func compare<T: Comparable>(to: Self, key: KeyPath<Self, T>, order: SortOrder = .ASC) -> Bool? {
        return self[keyPath: key].compare(to: to[keyPath: key], order: order)
    }
}

class Sorter<T: Sortable> {
    var key: PartialKeyPath<T>
    var description: AnyHashable?
    var priority: Comparator<T>?
    var comparison: Comparator<T>

    init<U: Comparable>(key: KeyPath<T, U>, order: SortOrder = .ASC, description: AnyHashable? = nil, priority: Comparator<T>? = nil) {
        self.key = key as PartialKeyPath<T>
        self.description = description
        self.priority = priority
        self.comparison = { $0.compare(to: $1, key: key, order: order) }
    }
}

extension Array where Element: Sortable {
    private func findByDescription(_ description: AnyHashable) -> Sorter<Element>? {
        return Element.sorters.first{ $0.description == description }
    }
    
    private func findByKey<U: Comparable>(_ key: KeyPath<Element, U>) -> Sorter<Element>? {
        return Element.sorters.first{ $0.key == key as PartialKeyPath<Element> }
    }
    
    mutating func sort(description: AnyHashable) {
        self.sort(sorter: self.findByDescription(description))
    }
    
    mutating func sort<U: Comparable>(key: KeyPath<Element, U>) {
        self.sort(sorter: self.findByKey(key))
    }

    mutating func sort(sorter: Sorter<Element>?) {
        guard let sorter: Sorter<Element> = sorter else {
            return
        }

        self.sort(using: sorter)
    }
    
    mutating func sort(using sorter: Sorter<Element>) {
        self.sort { sorter.priority?($0, $1) ?? sorter.comparison($0, $1) ?? false }
    }
}

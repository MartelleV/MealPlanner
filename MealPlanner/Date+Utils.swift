//
//  Date+Utils.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 24/10/25.
//


import Foundation

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    func addingDays(_ d: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: d, to: self) ?? self
    }
}

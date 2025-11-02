//
//  IdeaModelTests.swift
//  IdeaBoxTests
//
//  Created by Harry Ng on 10/30/25.
//

import Foundation
import Testing
import SwiftData
@testable import IdeaBox

@Suite("Idea 模型測試")
struct IdeaModelTests {
    
    @Test("Idea 模型應該正確初始化所有必填欄位")
    func testIdeaInitializationWithRequiredFields() {
        // Given
        let title = "測試想法"
        let detail = "這是一個測試想法的詳細描述"
        
        // When
        let idea = Idea(title: title, detail: detail)
        
        // Then
        #expect(idea.title == title)
        #expect(idea.detail == detail)
        #expect(idea.isCompleted == false)
        #expect(idea.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }
    
    @Test("Idea 模型應該使用預設值初始化")
    func testIdeaInitializationWithDefaults() {
        // Given & When
        let idea = Idea(title: "簡單想法")
        
        // Then
        #expect(idea.title == "簡單想法")
        #expect(idea.detail == nil)
        #expect(idea.isCompleted == false)
        #expect(idea.sortOrder == nil)
    }
    
    @Test("Idea 模型的 createdAt 和 updatedAt 應該自動設定為當前時間")
    func testIdeaTimestampsAreAutoSet() {
        // Given
        let beforeCreation = Date()
        
        // When
        let idea = Idea(title: "時間戳測試")
        
        // Then
        let afterCreation = Date()
        #expect(idea.createdAt >= beforeCreation)
        #expect(idea.createdAt <= afterCreation)
        #expect(idea.updatedAt >= beforeCreation)
        #expect(idea.updatedAt <= afterCreation)
    }
    
    @Test("Idea 模型應該允許修改 isCompleted 狀態")
    func testIdeaCompletionToggle() {
        // Given
        let idea = Idea(title: "可完成的想法")
        let initialState = idea.isCompleted
        
        // When
        idea.isCompleted = true
        
        // Then
        #expect(initialState == false)
        #expect(idea.isCompleted == true)
    }
    
    @Test("Idea 模型應該允許設定自訂排序索引")
    func testIdeaSortOrder() {
        // Given
        let idea = Idea(title: "可排序的想法")
        
        // When
        idea.sortOrder = 1.5
        
        // Then
        #expect(idea.sortOrder == 1.5)
    }
    
    @Test("Idea 模型應該支援更新 detail 內容")
    func testIdeaDetailUpdate() {
        // Given
        let idea = Idea(title: "可編輯想法", detail: "原始描述")
        
        // When
        idea.detail = "更新後的描述"
        
        // Then
        #expect(idea.detail == "更新後的描述")
    }
    
    @Test("Idea 模型應該允許清空 detail")
    func testIdeaClearDetail() {
        // Given
        let idea = Idea(title: "有描述的想法", detail: "一些描述")
        
        // When
        idea.detail = nil
        
        // Then
        #expect(idea.detail == nil)
    }
}

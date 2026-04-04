// AddTaskSheet.swift
import SwiftUI

struct AddTaskSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let scope: TaskScope
    let onSave: (String, String, Date?, Task.Priority) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var selectedPriority: Task.Priority = .medium
    @State private var showCalendar = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            // Поле названия
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Название задачи")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                TextField("Например: Сдать проект", text: $title)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body)
                            }
                            
                            // Поле описания
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Описание")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                TextField("Добавьте детали...", text: $description, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)
                            }
                            
                            // Дедлайн
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Установить срок", isOn: $hasDeadline)
                                    .tint(Color.customBlueLight)
                                
                                if hasDeadline {
                                    Button {
                                        showCalendar = true
                                    } label: {
                                        HStack {
                                            Text(deadline.formatted(date: .long, time: .omitted))
                                                .foregroundColor(Color.customBlueLight)
                                            Spacer()
                                            Image(systemName: "calendar")
                                                .foregroundColor(Color.customBlueLight)
                                        }
                                        .padding()
                                        .background(Color.adaptiveTabBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .sheet(isPresented: $showCalendar) {
                                        CalendarSheet(selectedDate: $deadline, isPresented: $showCalendar)
                                    }
                                }
                            }
                            
                            // Приоритет
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Приоритет")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Picker("Приоритет", selection: $selectedPriority) {
                                    Text("Низкий").tag(Task.Priority.low)
                                    Text("Средний").tag(Task.Priority.medium)
                                    Text("Высокий").tag(Task.Priority.high)
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding(24)
                        .background(Color.adaptiveCard)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 80)
                }
                
                // Мышь
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("Mouse_Task")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350, height: 350)
                            .padding(.trailing, -10)
                            .padding(.bottom, -80)
                    }
                }
                .ignoresSafeArea(.keyboard)
            }
            .navigationTitle("Новая задача")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.adaptiveBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(Color.customBlueLight)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        onSave(
                            title,
                            description,
                            hasDeadline ? deadline : nil,
                            selectedPriority
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                    .foregroundColor(title.isEmpty ? .gray : Color.customBlueLight)
                }
            }
        }
    }
}

// MARK: - Calendar Sheet Component
struct CalendarSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Выберите дату",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .onChange(of: selectedDate) { oldValue, newValue in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPresented = false
                    }
                }
            }
            .navigationTitle("Выберите дату")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.height(450)])
        .presentationDragIndicator(.visible)
    }
}

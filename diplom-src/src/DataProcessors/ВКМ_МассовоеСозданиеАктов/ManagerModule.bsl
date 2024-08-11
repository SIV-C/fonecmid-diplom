
#Область ПрограммныйИнтерфейс

Функция СоздатьАкты(Дата) Экспорт
		
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	ДоговорыКонтрагентов.Ссылка КАК Ссылка,
	|	ДоговорыКонтрагентов.Организация КАК Организация,
	|	ДоговорыКонтрагентов.Владелец КАК Контрагент
	|ПОМЕСТИТЬ ВТ_Договора
	|ИЗ
	|	Справочник.ДоговорыКонтрагентов КАК ДоговорыКонтрагентов
	|ГДЕ
	|	ДоговорыКонтрагентов.ВКМ_ОкончанияДействия >= &ДатаНачала
	|	И ДоговорыКонтрагентов.ВКМ_НачалаДействия <= &ДатаОкончания
	|	И ДоговорыКонтрагентов.ВидДоговора = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровКонтрагентов.АбоненскоеОбслуживание)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	РеализацияТоваровУслуг.Ссылка КАК Ссылка,
	|	РеализацияТоваровУслуг.Контрагент КАК Контрагент,
	|	РеализацияТоваровУслуг.Договор КАК Договор
	|ПОМЕСТИТЬ ВТ_Реализации
	|ИЗ
	|	Документ.РеализацияТоваровУслуг КАК РеализацияТоваровУслуг
	|ГДЕ
	|	РеализацияТоваровУслуг.Дата МЕЖДУ &ДатаНачала И &ДатаОкончания
	|	И РеализацияТоваровУслуг.ПометкаУдаления = ЛОЖЬ
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ВТ_Договора.Ссылка КАК Договор,
	|	ВТ_Реализации.Ссылка КАК Реализация,
	|	ВТ_Договора.Организация КАК Организация,
	|	ВТ_Договора.Контрагент КАК Контрагент
	|ИЗ
	|	ВТ_Договора КАК ВТ_Договора
	|		ЛЕВОЕ СОЕДИНЕНИЕ ВТ_Реализации КАК ВТ_Реализации
	|		ПО ВТ_Договора.Ссылка = ВТ_Реализации.Договор";
	
	Запрос.УстановитьПараметр("ДатаНачала", НачалоМесяца(Дата));
	Запрос.УстановитьПараметр("ДатаОкончания", КонецМесяца(Дата));
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Выборка = РезультатЗапроса.Выбрать();  
	
	ВыборкаКоличество = Выборка.Количество();
	ТекВыборка = 1;
	
	СписокРеализацийМассив = Новый Массив;
	
	Пока Выборка.Следующий() Цикл
		
		СписокРеализацийСтруктура = Новый Структура;
		
			Если Не ЗначениеЗаполнено(Выборка.Реализация) Тогда
				НоваяРеализация = СоздатьРеализацию(Выборка.Договор, КонецМесяца(Дата)); 
				СписокРеализацийСтруктура.Вставить("Договор", Выборка.Договор); 
				СписокРеализацийСтруктура.Вставить("Реализация", НоваяРеализация); 
			Иначе 
				СписокРеализацийСтруктура.Вставить("Договор", Выборка.Договор); 
				СписокРеализацийСтруктура.Вставить("Реализация", Выборка.Реализация);	
			КонецЕсли;
		
		СписокРеализацийМассив.Добавить(СписокРеализацийСтруктура); 
		
		Процент = 100 - ЦЕЛ((ВыборкаКоличество - ТекВыборка)/ВыборкаКоличество*100); 
		ДлительныеОперации.СообщитьПрогресс(Процент);
		
		ТекВыборка = ТекВыборка+1;
		
	КонецЦикла;
	
	Возврат СписокРеализацийМассив;	
		
КонецФункции

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

Функция СоздатьРеализацию(Договор, ДатаСозданияНовойРеализации)
	
	НоваяРеализация = Документы.РеализацияТоваровУслуг.СоздатьДокумент();
	НоваяРеализация.ВКМ_ВыполнитьАвтозаполнение();
	НоваяРеализация.Дата = ДатаСозданияНовойРеализации;
	НоваяРеализация.Ответственный = Пользователи.ТекущийПользователь();
	НоваяРеализация.Договор = Договор;
	
	ДанныеДоговора = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(Договор, "Владелец, Организация");
	
	НоваяРеализация.Контрагент = ДанныеДоговора.Владелец;
	НоваяРеализация.Организация = ДанныеДоговора.Организация;
	
	Если НоваяРеализация.ПроверитьЗаполнение() Тогда
	
		Попытка
			НоваяРеализация.Записать(РежимЗаписиДокумента.Проведение, РежимПроведенияДокумента.Неоперативный);
		Исключение
			ОбщегоНазначения.СообщитьПользователю("Не удалось провести документ");
			НоваяРеализация = Документы.РеализацияТоваровУслуг.ПустаяСсылка();
		КонецПопытки
		
	КонецЕсли;	
		
	Возврат НоваяРеализация.Ссылка;
	
КонецФункции
	 

#КонецОбласти

import { Component, EventEmitter, Input, Output } from '@angular/core';
import { Louvor } from '../../models/louvor';
import { CommonModule } from '@angular/common';
import { SearchOption } from "../search-option/search-option";

@Component({
  selector: 'app-search-options',
  imports: [CommonModule, SearchOption],
  templateUrl: './search-options.html',
  styleUrl: './search-options.css'
})
export class SearchOptions {
  @Input() louvores: Louvor[] = [];
  @Input() canAddLouvor: boolean = true;
  @Output() addLouvor = new EventEmitter<Louvor>();

}

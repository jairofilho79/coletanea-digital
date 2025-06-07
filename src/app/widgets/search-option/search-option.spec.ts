import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SearchOption } from './search-option';

describe('SearchOption', () => {
  let component: SearchOption;
  let fixture: ComponentFixture<SearchOption>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SearchOption]
    })
    .compileComponents();

    fixture = TestBed.createComponent(SearchOption);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SearchOptions } from './search-options';

describe('SearchOptions', () => {
  let component: SearchOptions;
  let fixture: ComponentFixture<SearchOptions>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SearchOptions]
    })
    .compileComponents();

    fixture = TestBed.createComponent(SearchOptions);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

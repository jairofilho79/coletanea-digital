import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PdfCollection } from './pdf-collection';

describe('PdfCollection', () => {
  let component: PdfCollection;
  let fixture: ComponentFixture<PdfCollection>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PdfCollection]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PdfCollection);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

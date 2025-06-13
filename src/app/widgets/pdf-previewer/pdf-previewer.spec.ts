import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PdfPreviewer } from './pdf-previewer';

describe('PdfPreviewer', () => {
  let component: PdfPreviewer;
  let fixture: ComponentFixture<PdfPreviewer>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PdfPreviewer]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PdfPreviewer);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});

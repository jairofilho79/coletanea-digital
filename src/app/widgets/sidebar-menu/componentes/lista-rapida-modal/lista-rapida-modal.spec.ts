import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ListaRapidaModal } from './lista-rapida-modal';

describe('ListaRapidaModal', () => {
  let component: ListaRapidaModal;
  let fixture: ComponentFixture<ListaRapidaModal>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ListaRapidaModal]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ListaRapidaModal);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
